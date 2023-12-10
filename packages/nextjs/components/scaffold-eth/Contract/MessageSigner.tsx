import { Dispatch, SetStateAction } from "react";
import { getContractFunctionArgsMap } from "~~/components/scaffold-eth";
import { signMessage } from "~~/utils/scaffold-eth/messageSigner";

const FIELDS = ["message", "signature"];

type PermitSignerProps<S> = {
  form: S;
  setForm: Dispatch<SetStateAction<S>>;
};
export const MessageSigner = ({ form, setForm }: PermitSignerProps<Record<string, any>>) => (
  <>
    {form && (
      <button
        className={`btn btn-secondary btn-sm`}
        onClick={async () => {
          const { message, signature, signer } = getContractFunctionArgsMap(form);
          if (!signature) throw new Error("No signature key found");

          try {
            const { signature: sign, signer: address } = await signMessage(form[message]);
            setForm({ ...form, [signature]: sign, [signer]: address });
          } catch (e) {
            console.error(e);
          }
        }}
      >
        SIGN
      </button>
    )}
  </>
);

export const hasMessageSignerFields = (form: Record<string, any>) => {
  const argsMap = getContractFunctionArgsMap(form);
  return FIELDS.every(field => argsMap[field]);
};
