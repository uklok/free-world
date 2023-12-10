import { Dispatch, SetStateAction } from "react";
import { signERC2612Permit } from "eth-permit";
import { getContractFunctionArgsMap } from "~~/components/scaffold-eth";

const FIELDS = ["owner", "spender", "value", "deadline", "v", "r", "s"];

type PermitSignerProps<S> = {
  form: S;
  setForm: Dispatch<SetStateAction<S>>;
  contractAddress: string;
};
export const PermitSigner = ({ form, setForm, contractAddress }: PermitSignerProps<Record<string, any>>) => (
  <>
    {form && (
      <button
        className={`btn btn-secondary btn-sm normal-case font-thin bg-base-100`}
        onClick={async () => {
          const {
            owner: ownerKey,
            spender: spenderKey,
            value: valueKey,
            expire: expireKey,
            deadline: deadlineKey,
            v: vKey,
            r: rKey,
            s: sKey,
          } = getContractFunctionArgsMap(form);

          const { [ownerKey]: owner, [spenderKey]: spender, [valueKey]: value, [expireKey]: expire } = form;

          try {
            const { deadline, v, r, s } = await signERC2612Permit(
              window.ethereum,
              contractAddress,
              owner,
              spender,
              `${value}`,
              expire,
            );

            setForm({ ...form, [deadlineKey]: deadline, [vKey]: v, [rKey]: r, [sKey]: s });
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

export const hasPermitFields = (form: Record<string, any>) => {
  const argsMap = getContractFunctionArgsMap(form);
  return FIELDS.every(field => argsMap[field]);
};
